package com.enterprise.cswmsinbound.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PutawayResponse {
    private String asnNumber;
    private String campaignCode;
    private String sku;
    private Integer totalQuantityPutaway;
    private List<BinDetail> bins;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime completedAt;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class BinDetail {
        private String  warehouseZone;
        private String  warehouseAisle;
        private String  warehouseBin;
        private Integer quantity;
    }
}
