package com.enterprise.cstms.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;
import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AssignDriverRequest {

    @NotBlank @Size(max = 100)
    private String driverName;

    @NotBlank @Size(max = 50)
    private String truckNumber;

    private LocalDate pickupDate;
    private LocalDate estimatedDeliveryDate;
    private String notes;
}
