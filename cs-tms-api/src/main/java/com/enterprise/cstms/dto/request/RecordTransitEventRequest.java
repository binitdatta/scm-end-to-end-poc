package com.enterprise.cstms.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDateTime;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RecordTransitEventRequest {

    @NotBlank @Size(max = 50)
    private String eventCode;

    @Size(max = 255)
    private String eventDescription;

    @Size(max = 200)
    private String location;

    private LocalDateTime eventAt;

    @Size(max = 50)
    private String source;
}
