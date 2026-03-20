package com.enterprise.cstms.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StoreDeliveryResponse {
    private String  externalId;
    private String  storeExternalId;
    private String  storeNumber;
    private String  storeName;
    private String  city;
    private String  stateCode;
    private String  sku;
    private Integer quantity;
    private String  cartonLabel;
    private Integer deliveredQuantity;
    private String  podSignatory;
    private String  podNotes;
    private String  status;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime deliveredAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime podConfirmedAt;
}
