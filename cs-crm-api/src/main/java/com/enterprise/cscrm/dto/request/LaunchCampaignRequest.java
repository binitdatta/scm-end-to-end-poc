package com.enterprise.cscrm.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LaunchCampaignRequest {

    @NotBlank(message = "triggeredBy is required")
    private String triggeredBy;

    private String notes;
}
