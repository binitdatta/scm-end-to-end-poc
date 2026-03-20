package com.enterprise.cstms.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DeliveryLoadResponse {

    private String externalId;
    private String loadNumber;
    private String shipmentExternalId;
    private String shipmentNumber;
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
    private String carrierName;
    private String proNumber;
    private String driverName;
    private String truckNumber;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requiredDeliveryDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate pickupDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate estimatedDeliveryDate;

    private String status;
    private String notes;
    private String createdBy;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    private List<StoreDeliveryResponse> storeDeliveries;
}
