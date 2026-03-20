package com.enterprise.csvendor.service;

import com.enterprise.csvendor.dto.request.CreateVendorRequest;
import com.enterprise.csvendor.dto.response.VendorResponse;
import com.enterprise.csvendor.entity.Vendor;
import com.enterprise.csvendor.exception.DuplicateResourceException;
import com.enterprise.csvendor.exception.ResourceNotFoundException;
import com.enterprise.csvendor.messaging.VendorEventMessage;
import com.enterprise.csvendor.messaging.VendorEventPublisher;
import com.enterprise.csvendor.repository.VendorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class VendorService {

    private final VendorRepository     vendorRepository;
    private final VendorEventPublisher publisher;

    // ── CREATE ────────────────────────────────────────────────────────────────

    @Transactional
    public VendorResponse createVendor(CreateVendorRequest req) {
        if (vendorRepository.existsByVendorCode(req.getVendorCode())) {
            throw new DuplicateResourceException(
                    "Vendor code already exists: " + req.getVendorCode());
        }

        Vendor.Category category = req.getCategory() != null
                ? Vendor.Category.valueOf(req.getCategory())
                : Vendor.Category.TOY_MANUFACTURER;

        Vendor vendor = Vendor.builder()
                .externalId(UUID.randomUUID().toString())
                .vendorName(req.getVendorName())
                .vendorCode(req.getVendorCode())
                .country(Vendor.Country.valueOf(req.getCountry()))
                .contactName(req.getContactName())
                .contactEmail(req.getContactEmail())
                .contactPhone(req.getContactPhone())
                .address(req.getAddress())
                .status(Vendor.Status.ACTIVE)
                .category(category)
                .leadTimeDays(req.getLeadTimeDays())
                .paymentTerms(req.getPaymentTerms())
                .scorecardRating(req.getScorecardRating())
                .build();

        vendor = vendorRepository.save(vendor);

        // Notify Control Tower
        VendorEventMessage message = VendorEventMessage.builder()
                .eventType("VENDOR_CREATED")
                .vendorExternalId(vendor.getExternalId())
                .vendorCode(vendor.getVendorCode())
                .vendorName(vendor.getVendorName())
                .vendorCountry(vendor.getCountry().name())
                .triggeredBy("system")
                .notes("New vendor registered: " + vendor.getVendorCode())
                .eventTimestamp(LocalDateTime.now())
                .build();
        publisher.publishVendorCreated(message);

        log.info("Vendor created: code={} country={}", vendor.getVendorCode(), vendor.getCountry());
        return toResponse(vendor);
    }

    // ── GET ───────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public VendorResponse getVendor(String externalId) {
        return toResponse(findByExternalIdOrThrow(externalId));
    }

    @Transactional(readOnly = true)
    public List<VendorResponse> getAllVendors() {
        return vendorRepository.findAll().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<VendorResponse> getVendorsByCountry(String country) {
        return vendorRepository
                .findByCountryAndStatus(Vendor.Country.valueOf(country), Vendor.Status.ACTIVE)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    // ── SCORECARD ─────────────────────────────────────────────────────────────

    @Transactional
    public VendorResponse updateScorecard(String externalId, java.math.BigDecimal rating) {
        Vendor vendor = findByExternalIdOrThrow(externalId);
        vendor.setScorecardRating(rating);
        vendor = vendorRepository.save(vendor);
        log.info("Scorecard updated: vendor={} rating={}", vendor.getVendorCode(), rating);
        return toResponse(vendor);
    }

    // ── PACKAGE-LEVEL LOOKUP (used by RfqService) ─────────────────────────────

    public Vendor findByExternalIdOrThrow(String externalId) {
        return vendorRepository.findByExternalId(externalId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Vendor not found: " + externalId));
    }

    // ── MAPPER ────────────────────────────────────────────────────────────────

    public VendorResponse toResponse(Vendor v) {
        return VendorResponse.builder()
                .externalId(v.getExternalId())
                .vendorName(v.getVendorName())
                .vendorCode(v.getVendorCode())
                .country(v.getCountry().name())
                .contactName(v.getContactName())
                .contactEmail(v.getContactEmail())
                .contactPhone(v.getContactPhone())
                .address(v.getAddress())
                .status(v.getStatus().name())
                .category(v.getCategory().name())
                .leadTimeDays(v.getLeadTimeDays())
                .paymentTerms(v.getPaymentTerms())
                .scorecardRating(v.getScorecardRating())
                .createdAt(v.getCreatedAt())
                .updatedAt(v.getUpdatedAt())
                .build();
    }
}
