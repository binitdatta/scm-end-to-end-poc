package com.enterprise.cstms.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ConfirmPodRequest {

    @NotNull @Min(0)
    private Integer deliveredQuantity;

    @NotBlank @Size(max = 100)
    private String podSignatory;

    private String podNotes;

    private LocalDateTime deliveredAt;
}
