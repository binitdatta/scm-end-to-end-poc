package com.enterprise.cswmsinbound.messaging;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class WmsInboundEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Value("${wms.inbound.rabbitmq.exchange}")
    private String exchange;

    @Value("${wms.inbound.rabbitmq.routing-key.asn-created}")
    private String asnCreatedKey;

    @Value("${wms.inbound.rabbitmq.routing-key.asn-scheduled}")
    private String asnScheduledKey;

    @Value("${wms.inbound.rabbitmq.routing-key.shipment-arrived}")
    private String shipmentArrivedKey;

    @Value("${wms.inbound.rabbitmq.routing-key.receiving-completed}")
    private String receivingCompletedKey;

    @Value("${wms.inbound.rabbitmq.routing-key.putaway-completed}")
    private String putawayCompletedKey;

    public void publishAsnCreated(WmsInboundEventMessage m)       { publish(asnCreatedKey, m); }
    public void publishAsnScheduled(WmsInboundEventMessage m)     { publish(asnScheduledKey, m); }
    public void publishShipmentArrived(WmsInboundEventMessage m)  { publish(shipmentArrivedKey, m); }
    public void publishReceivingCompleted(WmsInboundEventMessage m){ publish(receivingCompletedKey, m); }
    public void publishPutawayCompleted(WmsInboundEventMessage m) { publish(putawayCompletedKey, m); }

    private void publish(String routingKey, WmsInboundEventMessage message) {
        message.setRoutingKey(routingKey);
        try {
            rabbitTemplate.convertAndSend(exchange, routingKey, message);
            log.info("Published exchange={} routingKey={} asn={} campaign={}",
                    exchange, routingKey, message.getAsnNumber(), message.getCampaignCode());
        } catch (Exception ex) {
            log.error("RabbitMQ publish failed routingKey={} error={}", routingKey, ex.getMessage(), ex);
            throw new RuntimeException("RabbitMQ publish failed: " + routingKey, ex);
        }
    }
}
