package com.enterprise.csvendor.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateVendorRequest {

    @NotBlank @Size(max = 200)
    private String vendorName;

    @NotBlank @Size(max = 50)
    private String vendorCode;

    @NotBlank
    private String country;       // CHINA | VIETNAM | INDIA | THAILAND | OTHER

    @Size(max = 150)
    private String contactName;

    @Email @Size(max = 255)
    private String contactEmail;

    @Size(max = 40)
    private String contactPhone;

    private String address;

    private String category;      // TOY_MANUFACTURER | PACKAGING | LOGISTICS | OTHER

    @Min(1)
    private Integer leadTimeDays;

    @Size(max = 100)
    private String paymentTerms;

    @DecimalMin("0.0") @DecimalMax("5.0")
    private BigDecimal scorecardRating;
}
