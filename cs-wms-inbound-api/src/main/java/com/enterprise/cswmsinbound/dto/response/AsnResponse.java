package com.enterprise.cswmsinbound.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AsnResponse {

    private String externalId;
    private String asnNumber;
    private String poExternalId;
    private String poNumber;
    private String campaignExternalId;
    private String campaignCode;
    private String vendorExternalId;
    private String vendorCode;
    private String vendorName;
    private String vendorCountry;
    private String sku;
    private String toyDescription;
    private Integer expectedQuantity;
    private String unitOfMeasure;
    private String carrierName;
    private String trackingNumber;
    private String originPort;
    private String destinationPort;
    private String incoterms;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate estimatedArrivalDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate actualArrivalDate;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime dockAppointmentDate;

    private String dockDoor;
    private String status;
    private String notes;
    private String createdBy;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;
}
