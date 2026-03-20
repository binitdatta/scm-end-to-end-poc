package com.enterprise.csoms.repository;

import com.enterprise.csoms.entity.OrderEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface OrderEventRepository extends JpaRepository<OrderEvent, Long> {
    List<OrderEvent> findByStoreOrderIdOrderByEventAtDesc(Long storeOrderId);
}
