package com.enterprise.csoms.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AllocateOrderRequest {

    @NotBlank
    private String allocatedBy;

    private String notes;
}
