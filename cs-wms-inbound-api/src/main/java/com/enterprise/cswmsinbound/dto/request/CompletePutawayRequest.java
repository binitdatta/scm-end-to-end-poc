package com.enterprise.cswmsinbound.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.util.List;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CompletePutawayRequest {

    @NotNull @NotEmpty
    private List<BinAllocation> binAllocations;

    @NotBlank
    private String completedBy;

    private String notes;

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
    public static class BinAllocation {
        @NotBlank private String  warehouseZone;
        @NotBlank private String  warehouseAisle;
        @NotBlank private String  warehouseBin;
        @NotNull  @Min(1) private Integer quantity;
    }
}
