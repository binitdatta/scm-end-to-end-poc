package com.enterprise.csvendor.messaging;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class VendorEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Value("${vendor.rabbitmq.exchange}")
    private String exchange;

    @Value("${vendor.rabbitmq.routing-key.rfq-opened}")
    private String rfqOpenedKey;

    @Value("${vendor.rabbitmq.routing-key.rfq-awarded}")
    private String rfqAwardedKey;

    @Value("${vendor.rabbitmq.routing-key.rfq-cancelled}")
    private String rfqCancelledKey;

    @Value("${vendor.rabbitmq.routing-key.quote-submitted}")
    private String quoteSubmittedKey;

    @Value("${vendor.rabbitmq.routing-key.vendor-created}")
    private String vendorCreatedKey;

    public void publishRfqOpened(VendorEventMessage message) {
        publish(rfqOpenedKey, message);
    }

    public void publishRfqAwarded(VendorEventMessage message) {
        publish(rfqAwardedKey, message);
    }

    public void publishRfqCancelled(VendorEventMessage message) {
        publish(rfqCancelledKey, message);
    }

    public void publishQuoteSubmitted(VendorEventMessage message) {
        publish(quoteSubmittedKey, message);
    }

    public void publishVendorCreated(VendorEventMessage message) {
        publish(vendorCreatedKey, message);
    }

    private void publish(String routingKey, VendorEventMessage message) {
        message.setRoutingKey(routingKey);
        try {
            rabbitTemplate.convertAndSend(exchange, routingKey, message);
            log.info("Published to exchange={} routingKey={} rfq={} vendor={}",
                    exchange, routingKey, message.getRfqNumber(), message.getVendorCode());
        } catch (Exception ex) {
            log.error("RabbitMQ publish failed routingKey={} error={}", routingKey, ex.getMessage(), ex);
            throw new RuntimeException("RabbitMQ publish failed for routingKey: " + routingKey, ex);
        }
    }
}
