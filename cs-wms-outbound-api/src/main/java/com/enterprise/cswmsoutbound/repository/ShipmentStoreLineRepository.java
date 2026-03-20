package com.enterprise.cswmsoutbound.repository;

import com.enterprise.cswmsoutbound.entity.ShipmentStoreLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ShipmentStoreLineRepository extends JpaRepository<ShipmentStoreLine, Long> {
    List<ShipmentStoreLine> findByShipmentId(Long shipmentId);
}
