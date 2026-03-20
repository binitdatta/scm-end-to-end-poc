package com.enterprise.cswmsinbound.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class InventoryResponse {
    private String  sku;
    private String  campaignCode;
    private String  warehouseZone;
    private String  warehouseAisle;
    private String  warehouseBin;
    private Integer quantityOnHand;
    private Integer quantityReserved;
    private Integer quantityAvailable;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate lastReceiptDate;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime lastUpdatedAt;
}
