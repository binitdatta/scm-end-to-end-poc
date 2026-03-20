package com.enterprise.cscrm.messaging;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.time.LocalDateTime;

/**
 * JSON payload published to RabbitMQ for every campaign lifecycle event.
 * The Control Tower Flask app deserializes this from the queue.
 *
 * Routing key pattern: erp.crm.campaign.<event>
 */
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CampaignEventMessage {

    /** Source ERP service identifier */
    @Builder.Default
    private String source = "cs-crm-api";

    /** RabbitMQ routing key this message was published with */
    private String routingKey;

    /** Campaign identifiers */
    private String campaignExternalId;
    private String campaignCode;
    private String campaignName;

    /** Status transition */
    private String previousStatus;
    private String newStatus;
    private String eventType;

    /** Additional context */
    private String triggeredBy;
    private String targetRegion;
    private String notes;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime eventTimestamp;
}