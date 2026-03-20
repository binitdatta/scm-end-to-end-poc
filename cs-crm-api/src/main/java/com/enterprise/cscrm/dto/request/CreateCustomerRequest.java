package com.enterprise.cscrm.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateCustomerRequest {

    @NotBlank @Size(max = 100)
    private String firstName;

    @NotBlank @Size(max = 100)
    private String lastName;

    @NotBlank @Email @Size(max = 255)
    private String email;

    @Size(max = 30)
    private String phone;

    /** STANDARD | GOLD | PLATINUM — defaults to STANDARD if null */
    private String tier;
}
