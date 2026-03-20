package com.enterprise.cswmsoutbound.repository;

import com.enterprise.cswmsoutbound.entity.PickWaveLine;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface PickWaveLineRepository extends JpaRepository<PickWaveLine, Long> {
    List<PickWaveLine> findByPickWaveId(Long pickWaveId);
    Optional<PickWaveLine> findByExternalId(String externalId);
}
