package com.enterprise.cswmsinbound.repository;

import com.enterprise.cswmsinbound.entity.AsnEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface AsnEventRepository extends JpaRepository<AsnEvent, Long> {
    List<AsnEvent> findByAsnIdOrderByEventAtDesc(Long asnId);
}
