package com.enterprise.cscrm.config;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ configuration for cs-crm-api.
 *
 * This service is a PUBLISHER ONLY.
 * It declares one durable Topic exchange — erp.topic.exchange.
 * The Control Tower Flask app owns queue creation and bindings.
 *
 * Routing key pattern:  erp.crm.<entity>.<event>
 * Examples:
 *   erp.crm.campaign.launched
 *   erp.crm.campaign.completed
 *   erp.crm.customer.created
 */
@Configuration
public class RabbitMQConfig {

    @Value("${crm.rabbitmq.exchange}")
    private String exchangeName;

    /**
     * Durable topic exchange shared across all ERP services.
     * If it already exists in RabbitMQ with the same config, this is a no-op.
     */
    @Bean
    public TopicExchange erpTopicExchange() {
        return new TopicExchange(exchangeName, true, false);
    }

    /**
     * Use JSON for all messages — the Control Tower can parse them directly in Python.
     */
    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    /**
     * RabbitTemplate wired with JSON converter.
     */
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(jsonMessageConverter());
        return template;
    }
}
