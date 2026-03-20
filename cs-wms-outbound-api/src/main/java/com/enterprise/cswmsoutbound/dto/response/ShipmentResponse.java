package com.enterprise.cswmsoutbound.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ShipmentResponse {

    private String externalId;
    private String shipmentNumber;
    private String waveNumber;
    private String storeOrderExternalId;
    private String storeOrderNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String regionCode;
    private String distributionDc;
    private String sku;
    private String toyDescription;
    private Integer totalCartons;
    private Integer totalUnits;
    private Integer unitsPerCarton;
    private String carrierName;
    private String proNumber;
    private String destinationRegion;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requiredDeliveryDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate estimatedShipDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate actualShipDate;

    private String status;
    private String notes;
    private String createdBy;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    private List<StoreLineResponse> storeLines;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class StoreLineResponse {
        private String  storeExternalId;
        private String  storeNumber;
        private String  storeName;
        private String  city;
        private String  stateCode;
        private Integer quantity;
        private String  cartonLabel;
        private String  status;
    }
}
