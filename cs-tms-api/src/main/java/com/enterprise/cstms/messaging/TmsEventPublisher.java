package com.enterprise.cstms.messaging;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class TmsEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Value("${tms.rabbitmq.exchange}")
    private String exchange;

    @Value("${tms.rabbitmq.routing-key.load-created}")              private String loadCreatedKey;
    @Value("${tms.rabbitmq.routing-key.load-assigned}")             private String loadAssignedKey;
    @Value("${tms.rabbitmq.routing-key.load-in-transit}")           private String loadInTransitKey;
    @Value("${tms.rabbitmq.routing-key.load-completed}")            private String loadCompletedKey;
    @Value("${tms.rabbitmq.routing-key.delivery-out-for-delivery}") private String outForDeliveryKey;
    @Value("${tms.rabbitmq.routing-key.delivery-pod-confirmed}")    private String podConfirmedKey;

    public void publishLoadCreated(TmsEventMessage m)     { publish(loadCreatedKey, m); }
    public void publishLoadAssigned(TmsEventMessage m)    { publish(loadAssignedKey, m); }
    public void publishLoadInTransit(TmsEventMessage m)   { publish(loadInTransitKey, m); }
    public void publishLoadCompleted(TmsEventMessage m)   { publish(loadCompletedKey, m); }
    public void publishOutForDelivery(TmsEventMessage m)  { publish(outForDeliveryKey, m); }
    public void publishPodConfirmed(TmsEventMessage m)    { publish(podConfirmedKey, m); }

    private void publish(String routingKey, TmsEventMessage message) {
        message.setRoutingKey(routingKey);
        try {
            rabbitTemplate.convertAndSend(exchange, routingKey, message);
            log.info("Published exchange={} routingKey={} load={} campaign={}",
                    exchange, routingKey, message.getLoadNumber(), message.getCampaignCode());
        } catch (Exception ex) {
            log.error("RabbitMQ publish failed routingKey={} error={}", routingKey, ex.getMessage(), ex);
            throw new RuntimeException("RabbitMQ publish failed: " + routingKey, ex);
        }
    }
}
