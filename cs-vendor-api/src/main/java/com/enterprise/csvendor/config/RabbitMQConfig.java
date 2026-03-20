package com.enterprise.csvendor.config;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ configuration for cs-vendor-api.
 *
 * Publisher only — declares the shared durable topic exchange.
 * Queue creation and bindings are owned by the Control Tower Flask app.
 *
 * Routing key pattern:  erp.vendor.<entity>.<event>
 * Examples:
 *   erp.vendor.rfq.opened
 *   erp.vendor.rfq.awarded
 *   erp.vendor.quote.submitted
 *   erp.vendor.vendor.created
 */
@Configuration
public class RabbitMQConfig {

    @Value("${vendor.rabbitmq.exchange}")
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
