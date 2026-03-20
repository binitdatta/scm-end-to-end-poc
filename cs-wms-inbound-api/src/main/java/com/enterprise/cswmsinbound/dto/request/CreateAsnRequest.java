package com.enterprise.cswmsinbound.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateAsnRequest {

    @NotBlank @Size(max = 50)
    private String asnNumber;

    @NotBlank @Size(max = 64)
    private String poExternalId;

    @NotBlank @Size(max = 50)
    private String poNumber;

    @NotBlank @Size(max = 64)
    private String campaignExternalId;

    @NotBlank @Size(max = 50)
    private String campaignCode;

    @NotBlank @Size(max = 64)
    private String vendorExternalId;

    @NotBlank @Size(max = 50)
    private String vendorCode;

    @NotBlank @Size(max = 200)
    private String vendorName;

    @NotBlank
    private String vendorCountry;

    @NotBlank @Size(max = 50)
    private String sku;

    @NotBlank @Size(max = 200)
    private String toyDescription;

    @NotNull @Min(1)
    private Integer expectedQuantity;

    @Size(max = 100)
    private String carrierName;

    @Size(max = 100)
    private String trackingNumber;

    @Size(max = 100)
    private String originPort;

    @Size(max = 100)
    private String destinationPort;

    @Size(max = 20)
    private String incoterms;

    private LocalDate estimatedArrivalDate;
    private LocalDateTime dockAppointmentDate;

    @Size(max = 10)
    private String dockDoor;

    private String notes;

    @NotBlank
    private String createdBy;
}
