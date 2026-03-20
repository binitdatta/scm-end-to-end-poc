package com.enterprise.cswmsoutbound.config;

import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * RabbitMQ config for cs-wms-outbound-api.
 * Publisher only — declares the shared durable topic exchange.
 *
 * KEY outbound event: erp.wms.outbound.shipment.dispatched
 *   Payload carries shipment number, carrier PRO, region, store carton details.
 *   Consumed by cs-tms-api to track outbound delivery to stores.
 */
@Configuration
public class RabbitMQConfig {

    @Value("${wms.outbound.rabbitmq.exchange}")
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
