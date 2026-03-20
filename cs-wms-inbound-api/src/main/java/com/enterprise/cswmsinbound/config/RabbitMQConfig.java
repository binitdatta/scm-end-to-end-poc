package com.enterprise.cswmsinbound.config;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ config for cs-wms-inbound-api.
 * Publisher only — declares the shared durable topic exchange.
 *
 * KEY outbound event: erp.wms.inbound.putaway.completed
 *   Payload carries SKU, accepted quantity, bin locations.
 *   Consumed by cs-oms-api to mark inventory available for store allocation.
 */
@Configuration
public class RabbitMQConfig {

    @Value("${wms.inbound.rabbitmq.exchange}")
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
