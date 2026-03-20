package com.enterprise.cswmsoutbound.messaging;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class WmsOutboundEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Value("${wms.outbound.rabbitmq.exchange}")
    private String exchange;

    @Value("${wms.outbound.rabbitmq.routing-key.wave-created}")      private String waveCreatedKey;
    @Value("${wms.outbound.rabbitmq.routing-key.wave-completed}")     private String waveCompletedKey;
    @Value("${wms.outbound.rabbitmq.routing-key.shipment-created}")   private String shipmentCreatedKey;
    @Value("${wms.outbound.rabbitmq.routing-key.shipment-packed}")    private String shipmentPackedKey;
    @Value("${wms.outbound.rabbitmq.routing-key.shipment-manifested}")private String shipmentManifestedKey;
    @Value("${wms.outbound.rabbitmq.routing-key.shipment-dispatched}")private String shipmentDispatchedKey;

    public void publishWaveCreated(WmsOutboundEventMessage m)       { publish(waveCreatedKey, m); }
    public void publishWaveCompleted(WmsOutboundEventMessage m)     { publish(waveCompletedKey, m); }
    public void publishShipmentCreated(WmsOutboundEventMessage m)   { publish(shipmentCreatedKey, m); }
    public void publishShipmentPacked(WmsOutboundEventMessage m)    { publish(shipmentPackedKey, m); }
    public void publishShipmentManifested(WmsOutboundEventMessage m){ publish(shipmentManifestedKey, m); }
    public void publishShipmentDispatched(WmsOutboundEventMessage m){ publish(shipmentDispatchedKey, m); }

    private void publish(String routingKey, WmsOutboundEventMessage message) {
        message.setRoutingKey(routingKey);
        try {
            rabbitTemplate.convertAndSend(exchange, routingKey, message);
            log.info("Published exchange={} routingKey={} wave={} shipment={}",
                    exchange, routingKey, message.getWaveNumber(), message.getShipmentNumber());
        } catch (Exception ex) {
            log.error("RabbitMQ publish failed routingKey={} error={}", routingKey, ex.getMessage(), ex);
            throw new RuntimeException("RabbitMQ publish failed: " + routingKey, ex);
        }
    }
}
