package com.enterprise.csoms.repository;

import com.enterprise.csoms.entity.StoreOrderLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface StoreOrderLineRepository extends JpaRepository<StoreOrderLine, Long> {
    List<StoreOrderLine> findByStoreOrderId(Long storeOrderId);
}
