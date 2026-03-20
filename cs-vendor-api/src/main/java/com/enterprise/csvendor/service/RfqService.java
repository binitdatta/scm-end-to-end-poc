package com.enterprise.csvendor.service;

import com.enterprise.csvendor.dto.request.AwardRfqRequest;
import com.enterprise.csvendor.dto.request.CreateRfqRequest;
import com.enterprise.csvendor.dto.request.SubmitQuoteRequest;
import com.enterprise.csvendor.dto.response.AwardResponse;
import com.enterprise.csvendor.dto.response.QuoteResponse;
import com.enterprise.csvendor.dto.response.RfqResponse;
import com.enterprise.csvendor.entity.*;
import com.enterprise.csvendor.exception.DuplicateResourceException;
import com.enterprise.csvendor.exception.InvalidStateException;
import com.enterprise.csvendor.exception.ResourceNotFoundException;
import com.enterprise.csvendor.messaging.VendorEventMessage;
import com.enterprise.csvendor.messaging.VendorEventPublisher;
import com.enterprise.csvendor.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class RfqService {

    private final RfqRepository          rfqRepository;
    private final VendorRepository       vendorRepository;
    private final VendorQuoteRepository  quoteRepository;
    private final RfqAwardRepository     awardRepository;
    private final VendorService          vendorService;
    private final VendorEventPublisher   publisher;

    // ── CREATE RFQ ────────────────────────────────────────────────────────────

    @Transactional
    public RfqResponse createRfq(CreateRfqRequest req) {
        if (rfqRepository.existsByRfqNumber(req.getRfqNumber())) {
            throw new DuplicateResourceException(
                    "RFQ number already exists: " + req.getRfqNumber());
        }

        Rfq rfq = Rfq.builder()
                .externalId(UUID.randomUUID().toString())
                .rfqNumber(req.getRfqNumber())
                .campaignExternalId(req.getCampaignExternalId())
                .campaignCode(req.getCampaignCode())
                .title(req.getTitle())
                .description(req.getDescription())
                .toyCategory(req.getToyCategory())
                .quantityRequired(req.getQuantityRequired())
                .unit("PIECES")
                .targetUnitCostUsd(req.getTargetUnitCostUsd())
                .requiredByDate(req.getRequiredByDate())
                .submissionDeadline(req.getSubmissionDeadline())
                .status(Rfq.Status.DRAFT)
                .createdBy(req.getCreatedBy())
                .build();

        rfq = rfqRepository.save(rfq);

        // Invite vendors if provided
        if (req.getInviteVendorIds() != null && !req.getInviteVendorIds().isEmpty()) {
            for (String vendorExtId : req.getInviteVendorIds()) {
                Vendor vendor = vendorService.findByExternalIdOrThrow(vendorExtId);
                RfqVendor invite = RfqVendor.builder()
                        .rfq(rfq)
                        .vendor(vendor)
                        .build();
                rfq.getInvitedVendors().add(invite);
            }
            rfqRepository.save(rfq);
        }

        log.info("RFQ created: number={} campaign={}", rfq.getRfqNumber(), rfq.getCampaignCode());
        return toRfqResponse(rfq);
    }

    // ── OPEN RFQ (DRAFT → OPEN) ───────────────────────────────────────────────

    @Transactional
    public RfqResponse openRfq(String externalId, String triggeredBy) {
        Rfq rfq = findRfqOrThrow(externalId);

        if (rfq.getStatus() != Rfq.Status.DRAFT) {
            throw new InvalidStateException(
                    "RFQ can only be opened from DRAFT. Current: " + rfq.getStatus());
        }

        rfq.setStatus(Rfq.Status.OPEN);
        rfq = rfqRepository.save(rfq);

        VendorEventMessage message = VendorEventMessage.builder()
                .eventType("RFQ_OPENED")
                .rfqExternalId(rfq.getExternalId())
                .rfqNumber(rfq.getRfqNumber())
                .campaignExternalId(rfq.getCampaignExternalId())
                .campaignCode(rfq.getCampaignCode())
                .rfqStatus("OPEN")
                .triggeredBy(triggeredBy)
                .notes("RFQ opened for vendor quotes. Toy category: " + rfq.getToyCategory())
                .eventTimestamp(LocalDateTime.now())
                .build();
        publisher.publishRfqOpened(message);

        log.info("RFQ opened: number={}", rfq.getRfqNumber());
        return toRfqResponse(rfq);
    }

    // ── SUBMIT QUOTE ──────────────────────────────────────────────────────────

    @Transactional
    public QuoteResponse submitQuote(String rfqExternalId, SubmitQuoteRequest req) {
        Rfq rfq = findRfqOrThrow(rfqExternalId);

        if (rfq.getStatus() != Rfq.Status.OPEN && rfq.getStatus() != Rfq.Status.UNDER_REVIEW) {
            throw new InvalidStateException(
                    "Quotes can only be submitted to OPEN or UNDER_REVIEW RFQs. Current: "
                            + rfq.getStatus());
        }

        Vendor vendor = vendorService.findByExternalIdOrThrow(req.getVendorExternalId());

        if (quoteRepository.existsByRfqIdAndVendorId(rfq.getId(), vendor.getId())) {
            throw new DuplicateResourceException(
                    "Vendor " + vendor.getVendorCode() + " already submitted a quote for " + rfq.getRfqNumber());
        }

        BigDecimal total = req.getQuotedUnitCostUsd()
                .multiply(BigDecimal.valueOf(req.getQuotedQuantity()))
                .setScale(2, RoundingMode.HALF_UP);

        VendorQuote quote = VendorQuote.builder()
                .externalId(UUID.randomUUID().toString())
                .rfq(rfq)
                .vendor(vendor)
                .quotedUnitCostUsd(req.getQuotedUnitCostUsd())
                .quotedQuantity(req.getQuotedQuantity())
                .totalCostUsd(total)
                .leadTimeDays(req.getLeadTimeDays())
                .deliveryDate(req.getDeliveryDate())
                .paymentTerms(req.getPaymentTerms())
                .notes(req.getNotes())
                .status(VendorQuote.Status.SUBMITTED)
                .build();

        quote = quoteRepository.save(quote);

        // Move RFQ to UNDER_REVIEW once at least one quote arrives
        if (rfq.getStatus() == Rfq.Status.OPEN) {
            rfq.setStatus(Rfq.Status.UNDER_REVIEW);
            rfqRepository.save(rfq);
        }

        VendorEventMessage message = VendorEventMessage.builder()
                .eventType("QUOTE_SUBMITTED")
                .rfqExternalId(rfq.getExternalId())
                .rfqNumber(rfq.getRfqNumber())
                .campaignExternalId(rfq.getCampaignExternalId())
                .campaignCode(rfq.getCampaignCode())
                .rfqStatus(rfq.getStatus().name())
                .vendorExternalId(vendor.getExternalId())
                .vendorCode(vendor.getVendorCode())
                .vendorName(vendor.getVendorName())
                .vendorCountry(vendor.getCountry().name())
                .awardedUnitCostUsd(req.getQuotedUnitCostUsd())
                .totalAwardValueUsd(total)
                .triggeredBy(vendor.getVendorCode())
                .notes("Quote submitted: unit=$" + req.getQuotedUnitCostUsd()
                        + " leadTime=" + req.getLeadTimeDays() + "days")
                .eventTimestamp(LocalDateTime.now())
                .build();
        publisher.publishQuoteSubmitted(message);

        log.info("Quote submitted: rfq={} vendor={} unitCost={}",
                rfq.getRfqNumber(), vendor.getVendorCode(), req.getQuotedUnitCostUsd());
        return toQuoteResponse(quote);
    }

    // ── AWARD RFQ ─────────────────────────────────────────────────────────────

    @Transactional
    public AwardResponse awardRfq(String rfqExternalId, AwardRfqRequest req) {
        Rfq rfq = findRfqOrThrow(rfqExternalId);

        if (rfq.getStatus() != Rfq.Status.UNDER_REVIEW && rfq.getStatus() != Rfq.Status.OPEN) {
            throw new InvalidStateException(
                    "RFQ can only be awarded from OPEN or UNDER_REVIEW. Current: " + rfq.getStatus());
        }

        if (awardRepository.existsByRfqId(rfq.getId())) {
            throw new DuplicateResourceException(
                    "RFQ " + rfq.getRfqNumber() + " has already been awarded");
        }

        Vendor winner = vendorService.findByExternalIdOrThrow(req.getWinningVendorExternalId());

        // Find the winning vendor's quote
        VendorQuote winningQuote = quoteRepository
                .findByRfqIdAndVendorId(rfq.getId(), winner.getId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No quote found from vendor " + winner.getVendorCode()
                                + " for RFQ " + rfq.getRfqNumber()));

        BigDecimal unitCost = winningQuote.getQuotedUnitCostUsd();
        BigDecimal total    = unitCost
                .multiply(BigDecimal.valueOf(req.getAwardedQuantity()))
                .setScale(2, RoundingMode.HALF_UP);

        // Mark winning quote ACCEPTED, reject others
        quoteRepository.findByRfqId(rfq.getId()).forEach(q -> {
            if (q.getId().equals(winningQuote.getId())) {
                q.setStatus(VendorQuote.Status.ACCEPTED);
            } else {
                q.setStatus(VendorQuote.Status.REJECTED);
            }
            quoteRepository.save(q);
        });

        RfqAward award = RfqAward.builder()
                .externalId(UUID.randomUUID().toString())
                .rfq(rfq)
                .winningVendor(winner)
                .winningQuote(winningQuote)
                .awardedQuantity(req.getAwardedQuantity())
                .awardedUnitCostUsd(unitCost)
                .totalAwardValueUsd(total)
                .awardNotes(req.getAwardNotes())
                .awardedBy(req.getAwardedBy())
                .awardedAt(LocalDateTime.now())
                .rabbitmqPublished(false)
                .build();

        award = awardRepository.save(award);

        rfq.setStatus(Rfq.Status.AWARDED);
        rfqRepository.save(rfq);

        // Publish the key cross-system event — Procurement ERP will consume this
        // to trigger PO creation
        VendorEventMessage message = VendorEventMessage.builder()
                .eventType("RFQ_AWARDED")
                .rfqExternalId(rfq.getExternalId())
                .rfqNumber(rfq.getRfqNumber())
                .campaignExternalId(rfq.getCampaignExternalId())
                .campaignCode(rfq.getCampaignCode())
                .rfqStatus("AWARDED")
                .vendorExternalId(winner.getExternalId())
                .vendorCode(winner.getVendorCode())
                .vendorName(winner.getVendorName())
                .vendorCountry(winner.getCountry().name())
                .awardExternalId(award.getExternalId())
                .awardedQuantity(req.getAwardedQuantity())
                .awardedUnitCostUsd(unitCost)
                .totalAwardValueUsd(total)
                .awardedBy(req.getAwardedBy())
                .triggeredBy(req.getAwardedBy())
                .notes(req.getAwardNotes())
                .eventTimestamp(LocalDateTime.now())
                .build();
        publisher.publishRfqAwarded(message);

        // Mark published
        award.setRabbitmqPublished(true);
        awardRepository.save(award);

        log.info("RFQ awarded: rfq={} winner={} total=${}",
                rfq.getRfqNumber(), winner.getVendorCode(), total);
        return toAwardResponse(award, rfq, winner);
    }

    // ── CANCEL RFQ ────────────────────────────────────────────────────────────

    @Transactional
    public RfqResponse cancelRfq(String externalId, String triggeredBy, String notes) {
        Rfq rfq = findRfqOrThrow(externalId);

        if (rfq.getStatus() == Rfq.Status.AWARDED || rfq.getStatus() == Rfq.Status.CANCELLED) {
            throw new InvalidStateException(
                    "Cannot cancel an AWARDED or already CANCELLED RFQ. Current: " + rfq.getStatus());
        }

        String previousStatus = rfq.getStatus().name();
        rfq.setStatus(Rfq.Status.CANCELLED);
        rfq = rfqRepository.save(rfq);

        VendorEventMessage message = VendorEventMessage.builder()
                .eventType("RFQ_CANCELLED")
                .rfqExternalId(rfq.getExternalId())
                .rfqNumber(rfq.getRfqNumber())
                .campaignExternalId(rfq.getCampaignExternalId())
                .campaignCode(rfq.getCampaignCode())
                .rfqStatus("CANCELLED")
                .triggeredBy(triggeredBy)
                .notes("Cancelled from " + previousStatus + ". Reason: " + notes)
                .eventTimestamp(LocalDateTime.now())
                .build();
        publisher.publishRfqCancelled(message);

        log.info("RFQ cancelled: number={}", rfq.getRfqNumber());
        return toRfqResponse(rfq);
    }

    // ── READS ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public RfqResponse getRfq(String externalId) {
        return toRfqResponse(findRfqOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<RfqResponse> getAllRfqs() {
        return rfqRepository.findAll().stream()
                .map(this::toRfqResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<QuoteResponse> getQuotesForRfq(String rfqExternalId) {
        Rfq rfq = findRfqOrThrow(rfqExternalId);
        return quoteRepository.findByRfqId(rfq.getId()).stream()
                .map(this::toQuoteResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AwardResponse getAwardForRfq(String rfqExternalId) {
        Rfq rfq = findRfqOrThrow(rfqExternalId);
        RfqAward award = awardRepository.findByRfqId(rfq.getId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "No award found for RFQ: " + rfqExternalId));
        return toAwardResponse(award, rfq, award.getWinningVendor());
    }

    // ── HELPERS ───────────────────────────────────────────────────────────────

    private Rfq findRfqOrThrow(String externalId) {
        return rfqRepository.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "RFQ not found: " + externalId));
    }

    private RfqResponse toRfqResponse(Rfq r) {
        return RfqResponse.builder()
                .externalId(r.getExternalId())
                .rfqNumber(r.getRfqNumber())
                .campaignExternalId(r.getCampaignExternalId())
                .campaignCode(r.getCampaignCode())
                .title(r.getTitle())
                .description(r.getDescription())
                .toyCategory(r.getToyCategory())
                .quantityRequired(r.getQuantityRequired())
                .unit(r.getUnit())
                .targetUnitCostUsd(r.getTargetUnitCostUsd())
                .requiredByDate(r.getRequiredByDate())
                .submissionDeadline(r.getSubmissionDeadline())
                .status(r.getStatus().name())
                .createdBy(r.getCreatedBy())
                .createdAt(r.getCreatedAt())
                .updatedAt(r.getUpdatedAt())
                .build();
    }

    private QuoteResponse toQuoteResponse(VendorQuote q) {
        return QuoteResponse.builder()
                .externalId(q.getExternalId())
                .rfqNumber(q.getRfq().getRfqNumber())
                .vendorExternalId(q.getVendor().getExternalId())
                .vendorName(q.getVendor().getVendorName())
                .vendorCode(q.getVendor().getVendorCode())
                .vendorCountry(q.getVendor().getCountry().name())
                .quotedUnitCostUsd(q.getQuotedUnitCostUsd())
                .quotedQuantity(q.getQuotedQuantity())
                .totalCostUsd(q.getTotalCostUsd())
                .leadTimeDays(q.getLeadTimeDays())
                .deliveryDate(q.getDeliveryDate())
                .paymentTerms(q.getPaymentTerms())
                .notes(q.getNotes())
                .status(q.getStatus().name())
                .submittedAt(q.getSubmittedAt())
                .build();
    }

    private AwardResponse toAwardResponse(RfqAward a, Rfq rfq, Vendor winner) {
        return AwardResponse.builder()
                .externalId(a.getExternalId())
                .rfqNumber(rfq.getRfqNumber())
                .campaignCode(rfq.getCampaignCode())
                .winningVendorExternalId(winner.getExternalId())
                .winningVendorCode(winner.getVendorCode())
                .winningVendorName(winner.getVendorName())
                .winningVendorCountry(winner.getCountry().name())
                .awardedQuantity(a.getAwardedQuantity())
                .awardedUnitCostUsd(a.getAwardedUnitCostUsd())
                .totalAwardValueUsd(a.getTotalAwardValueUsd())
                .awardNotes(a.getAwardNotes())
                .awardedBy(a.getAwardedBy())
                .awardedAt(a.getAwardedAt())
                .build();
    }
}
