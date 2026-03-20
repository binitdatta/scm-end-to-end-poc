package com.enterprise.cscrm.messaging;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Publishes campaign lifecycle events to the shared erp.topic.exchange.
 * Each event uses a specific routing key so the Control Tower
 * can bind queues selectively (e.g. erp.crm.# to capture all CRM events).
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CampaignEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Value("${crm.rabbitmq.exchange}")
    private String exchange;

    @Value("${crm.rabbitmq.routing-key.campaign-launched}")
    private String launchedKey;

    @Value("${crm.rabbitmq.routing-key.campaign-paused}")
    private String pausedKey;

    @Value("${crm.rabbitmq.routing-key.campaign-completed}")
    private String completedKey;

    @Value("${crm.rabbitmq.routing-key.customer-created}")
    private String customerCreatedKey;

    public void publishCampaignLaunched(CampaignEventMessage message) {
        publish(launchedKey, message);
    }

    public void publishCampaignPaused(CampaignEventMessage message) {
        publish(pausedKey, message);
    }

    public void publishCampaignCompleted(CampaignEventMessage message) {
        publish(completedKey, message);
    }

    public void publishCustomerCreated(CampaignEventMessage message) {
        publish(customerCreatedKey, message);
    }

    private void publish(String routingKey, CampaignEventMessage message) {
        message.setRoutingKey(routingKey);
        try {
            rabbitTemplate.convertAndSend(exchange, routingKey, message);
            log.info("Published to exchange={} routingKey={} campaignCode={}",
                    exchange, routingKey, message.getCampaignCode());
        } catch (Exception ex) {
            log.error("Failed to publish RabbitMQ message routingKey={} error={}",
                    routingKey, ex.getMessage(), ex);
            throw new RuntimeException("RabbitMQ publish failed for routingKey: " + routingKey, ex);
        }
    }
}
