package com.enterprise.csprocurement.messaging;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class ProcurementEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    @Value("${procurement.rabbitmq.exchange}")
    private String exchange;

    @Value("${procurement.rabbitmq.routing-key.po-created}")       private String poCreatedKey;
    @Value("${procurement.rabbitmq.routing-key.po-approved}")      private String poApprovedKey;
    @Value("${procurement.rabbitmq.routing-key.po-sent}")          private String poSentKey;
    @Value("${procurement.rabbitmq.routing-key.po-acknowledged}")  private String poAcknowledgedKey;
    @Value("${procurement.rabbitmq.routing-key.po-in-production}") private String poInProductionKey;
    @Value("${procurement.rabbitmq.routing-key.po-ready-to-ship}") private String poReadyToShipKey;
    @Value("${procurement.rabbitmq.routing-key.po-completed}")     private String poCompletedKey;
    @Value("${procurement.rabbitmq.routing-key.po-cancelled}")     private String poCancelledKey;
    @Value("${procurement.rabbitmq.routing-key.invoice-received}") private String invoiceReceivedKey;
    @Value("${procurement.rabbitmq.routing-key.invoice-approved}") private String invoiceApprovedKey;
    @Value("${procurement.rabbitmq.routing-key.invoice-paid}")     private String invoicePaidKey;

    public void publishPoCreated(ProcurementEventMessage m)      { publish(poCreatedKey, m); }
    public void publishPoApproved(ProcurementEventMessage m)     { publish(poApprovedKey, m); }
    public void publishPoSent(ProcurementEventMessage m)         { publish(poSentKey, m); }
    public void publishPoAcknowledged(ProcurementEventMessage m) { publish(poAcknowledgedKey, m); }
    public void publishPoInProduction(ProcurementEventMessage m) { publish(poInProductionKey, m); }
    public void publishPoReadyToShip(ProcurementEventMessage m)  { publish(poReadyToShipKey, m); }
    public void publishPoCompleted(ProcurementEventMessage m)    { publish(poCompletedKey, m); }
    public void publishPoCancelled(ProcurementEventMessage m)    { publish(poCancelledKey, m); }
    public void publishInvoiceReceived(ProcurementEventMessage m){ publish(invoiceReceivedKey, m); }
    public void publishInvoiceApproved(ProcurementEventMessage m){ publish(invoiceApprovedKey, m); }
    public void publishInvoicePaid(ProcurementEventMessage m)    { publish(invoicePaidKey, m); }

    private void publish(String routingKey, ProcurementEventMessage message) {
        message.setRoutingKey(routingKey);
        try {
            rabbitTemplate.convertAndSend(exchange, routingKey, message);
            log.info("Published exchange={} routingKey={} po={}",
                    exchange, routingKey, message.getPoNumber());
        } catch (Exception ex) {
            log.error("RabbitMQ publish failed routingKey={} error={}", routingKey, ex.getMessage(), ex);
            throw new RuntimeException("RabbitMQ publish failed: " + routingKey, ex);
        }
    }
}
