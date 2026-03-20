package com.enterprise.cscrm.controller;

import com.enterprise.cscrm.dto.request.CreateCampaignRequest;
import com.enterprise.cscrm.dto.request.LaunchCampaignRequest;
import com.enterprise.cscrm.dto.response.ApiResponse;
import com.enterprise.cscrm.dto.response.CampaignResponse;
import com.enterprise.cscrm.service.CampaignService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/campaigns")
@RequiredArgsConstructor
public class CampaignController {

    private final CampaignService campaignService;

    /**
     * POST /api/v1/campaigns
     * Create a new campaign in DRAFT status.
     */
    @PostMapping
    public ResponseEntity<ApiResponse<CampaignResponse>> createCampaign(
            @Valid @RequestBody CreateCampaignRequest request) {
        CampaignResponse response = campaignService.createCampaign(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Campaign created successfully"));
    }

    /**
     * GET /api/v1/campaigns
     * List all campaigns.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<CampaignResponse>>> getAllCampaigns() {
        List<CampaignResponse> campaigns = campaignService.getAllCampaigns();
        return ResponseEntity.ok(ApiResponse.ok(campaigns, "Campaigns retrieved"));
    }

    /**
     * GET /api/v1/campaigns/{externalId}
     * Get a single campaign by its external UUID.
     */
    @GetMapping("/{externalId}")
    public ResponseEntity<ApiResponse<CampaignResponse>> getCampaign(
            @PathVariable String externalId) {
        CampaignResponse response = campaignService.getCampaign(externalId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Campaign retrieved"));
    }

    /**
     * POST /api/v1/campaigns/{externalId}/launch
     * Transition campaign from DRAFT → ACTIVE.
     * Publishes erp.crm.campaign.launched to RabbitMQ.
     */
    @PostMapping("/{externalId}/launch")
    public ResponseEntity<ApiResponse<CampaignResponse>> launchCampaign(
            @PathVariable String externalId,
            @Valid @RequestBody LaunchCampaignRequest request) {
        CampaignResponse response = campaignService.launchCampaign(externalId, request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Campaign launched successfully"));
    }

    /**
     * POST /api/v1/campaigns/{externalId}/pause
     * Transition campaign from ACTIVE → PAUSED.
     * Publishes erp.crm.campaign.paused to RabbitMQ.
     */
    @PostMapping("/{externalId}/pause")
    public ResponseEntity<ApiResponse<CampaignResponse>> pauseCampaign(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String triggeredBy = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes       = body != null ? body.get("notes") : null;
        CampaignResponse response = campaignService.pauseCampaign(externalId, triggeredBy, notes);
        return ResponseEntity.ok(ApiResponse.ok(response, "Campaign paused"));
    }

    /**
     * POST /api/v1/campaigns/{externalId}/complete
     * Transition campaign from ACTIVE/PAUSED → COMPLETED.
     * Publishes erp.crm.campaign.completed to RabbitMQ.
     */
    @PostMapping("/{externalId}/complete")
    public ResponseEntity<ApiResponse<CampaignResponse>> completeCampaign(
            @PathVariable String externalId,
            @RequestBody(required = false) Map<String, String> body) {
        String triggeredBy = body != null ? body.getOrDefault("triggeredBy", "system") : "system";
        String notes       = body != null ? body.get("notes") : null;
        CampaignResponse response = campaignService.completeCampaign(externalId, triggeredBy, notes);
        return ResponseEntity.ok(ApiResponse.ok(response, "Campaign completed"));
    }
}
