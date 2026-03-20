package com.enterprise.csprocurement.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ApprovePoRequest {

    @NotBlank
    private String approvedBy;

    private String notes;
}
