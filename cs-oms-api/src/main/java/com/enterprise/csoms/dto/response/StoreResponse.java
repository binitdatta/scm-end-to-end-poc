package com.enterprise.csoms.dto.response;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class StoreResponse {
    private String externalId;
    private String storeNumber;
    private String storeName;
    private String regionCode;
    private String regionName;
    private String address;
    private String city;
    private String stateCode;
    private String zipCode;
    private String status;
}
