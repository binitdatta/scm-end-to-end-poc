package com.enterprise.csoms.messaging;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class OmsEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Value("${oms.rabbitmq.exchange}")
    private String exchange;

    @Value("${oms.rabbitmq.routing-key.order-created}")    private String orderCreatedKey;
    @Value("${oms.rabbitmq.routing-key.order-submitted}")  private String orderSubmittedKey;
    @Value("${oms.rabbitmq.routing-key.order-allocated}")  private String orderAllocatedKey;
    @Value("${oms.rabbitmq.routing-key.order-picking}")    private String orderPickingKey;
    @Value("${oms.rabbitmq.routing-key.order-shipped}")    private String orderShippedKey;
    @Value("${oms.rabbitmq.routing-key.order-delivered}")  private String orderDeliveredKey;
    @Value("${oms.rabbitmq.routing-key.order-cancelled}")  private String orderCancelledKey;
    @Value("${oms.rabbitmq.routing-key.inventory-updated}")private String inventoryUpdatedKey;

    public void publishOrderCreated(OmsEventMessage m)    { publish(orderCreatedKey, m); }
    public void publishOrderSubmitted(OmsEventMessage m)  { publish(orderSubmittedKey, m); }
    public void publishOrderAllocated(OmsEventMessage m)  { publish(orderAllocatedKey, m); }
    public void publishOrderPicking(OmsEventMessage m)    { publish(orderPickingKey, m); }
    public void publishOrderShipped(OmsEventMessage m)    { publish(orderShippedKey, m); }
    public void publishOrderDelivered(OmsEventMessage m)  { publish(orderDeliveredKey, m); }
    public void publishOrderCancelled(OmsEventMessage m)  { publish(orderCancelledKey, m); }
    public void publishInventoryUpdated(OmsEventMessage m){ publish(inventoryUpdatedKey, m); }

    private void publish(String routingKey, OmsEventMessage message) {
        message.setRoutingKey(routingKey);
        try {
            rabbitTemplate.convertAndSend(exchange, routingKey, message);
            log.info("Published exchange={} routingKey={} order={} campaign={}",
                    exchange, routingKey, message.getOrderNumber(), message.getCampaignCode());
        } catch (Exception ex) {
            log.error("RabbitMQ publish failed routingKey={} error={}", routingKey, ex.getMessage(), ex);
            throw new RuntimeException("RabbitMQ publish failed: " + routingKey, ex);
        }
    }
}
