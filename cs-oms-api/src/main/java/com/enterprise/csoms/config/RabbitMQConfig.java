package com.enterprise.csoms.config;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ configuration for cs-oms-api.
 * Publisher only — declares the shared durable topic exchange.
 *
 * KEY outbound event: erp.oms.store-order.allocated
 *   Payload carries order number, region, SKU, total qty allocated,
 *   and per-store breakdown. Consumed by cs-wms-outbound-api to
 *   create pick waves and pack shipments.
 */
@Configuration
public class RabbitMQConfig {

    @Value("${oms.rabbitmq.exchange}")
    private String exchangeName;

    @Bean
    public TopicExchange erpTopicExchange() {
        return new TopicExchange(exchangeName, true, false);
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(jsonMessageConverter());
        return template;
    }
}
