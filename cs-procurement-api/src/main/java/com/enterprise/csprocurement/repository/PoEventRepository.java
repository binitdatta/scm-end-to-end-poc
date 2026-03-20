package com.enterprise.csprocurement.repository;

import com.enterprise.csprocurement.entity.PoEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface PoEventRepository extends JpaRepository<PoEvent, Long> {
    List<PoEvent> findByPurchaseOrderIdOrderByEventAtDesc(Long poId);
}
