package com.enterprise.csoms.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InventoryAvailabilityResponse {
    private String  sku;
    private String  campaignCode;
    private Integer quantityAvailable;
    private Integer quantityReserved;
    private Integer quantityRemaining;
    private String  sourceAsnNumber;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime lastUpdatedAt;
}
