package com.enterprise.cswmsoutbound.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PickWaveResponse {

    private String externalId;
    private String waveNumber;
    private String storeOrderExternalId;
    private String storeOrderNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String regionCode;
    private String sku;
    private String toyDescription;
    private Integer totalQuantity;
    private Integer pickedQuantity;
    private String pickZone;
    private String assignedTo;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requiredShipDate;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime startedAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime completedAt;

    private String status;
    private String notes;
    private String createdBy;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    private List<PickWaveLineResponse> lines;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class PickWaveLineResponse {
        private String  externalId;
        private String  warehouseZone;
        private String  warehouseAisle;
        private String  warehouseBin;
        private Integer quantityToPick;
        private Integer quantityPicked;
        private String  status;
    }
}
