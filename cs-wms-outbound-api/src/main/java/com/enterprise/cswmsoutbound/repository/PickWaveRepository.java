package com.enterprise.cswmsoutbound.repository;

import com.enterprise.cswmsoutbound.entity.PickWave;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface PickWaveRepository extends JpaRepository<PickWave, Long> {
    Optional<PickWave> findByExternalId(String externalId);
    Optional<PickWave> findByWaveNumber(String waveNumber);
    boolean existsByWaveNumber(String waveNumber);
    List<PickWave> findByStatus(PickWave.Status status);
    List<PickWave> findByCampaignCode(String campaignCode);
    Optional<PickWave> findByStoreOrderExternalId(String storeOrderExternalId);
}
