package com.enterprise.csoms.dto.response;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RegionResponse {
    private String  externalId;
    private String  regionCode;
    private String  regionName;
    private Integer storeCount;
    private String  distributionDc;
    private String  status;
}
