package com.enterprise.csoms.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StoreOrderResponse {

    private String externalId;
    private String orderNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String regionCode;
    private String regionName;
    private String distributionDc;
    private String sku;
    private String toyDescription;
    private Integer quantityRequested;
    private Integer quantityAllocated;
    private Integer quantityPerStore;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate requestedDeliveryDate;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime allocatedAt;

    private String status;
    private String createdBy;
    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    private List<OrderLineResponse> orderLines;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class OrderLineResponse {
        private String  storeExternalId;
        private String  storeNumber;
        private String  storeName;
        private String  city;
        private String  stateCode;
        private Integer quantityAllocated;
        private Integer quantityShipped;
        private Integer quantityDelivered;
        private String  status;
    }
}
