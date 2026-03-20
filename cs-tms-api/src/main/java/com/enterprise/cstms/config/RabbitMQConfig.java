package com.enterprise.cstms.config;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ config for cs-tms-api.
 * Publisher only — declares the shared durable topic exchange.
 *
 * KEY outbound event: erp.tms.delivery.pod-confirmed
 *   Payload carries load number, carrier PRO, campaign code, and full
 *   per-store POD details. This is the final event in the supply chain —
 *   consumed by the Flask Control Tower for BI and manager dashboards.
 */
@Configuration
public class RabbitMQConfig {

    @Value("${tms.rabbitmq.exchange}")
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
