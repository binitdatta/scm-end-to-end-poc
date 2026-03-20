package com.enterprise.csprocurement.config;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ config for cs-procurement-api.
 * Publisher only — declares the shared durable topic exchange.
 *
 * Routing key pattern: erp.procurement.<entity>.<event>
 * Key downstream event: erp.procurement.po.ready-to-ship
 *   → consumed by cs-wms-inbound-api to schedule inbound receiving
 */
@Configuration
public class RabbitMQConfig {

    @Value("${procurement.rabbitmq.exchange}")
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
