package com.enterprise.cswmsinbound.repository;

import com.enterprise.cswmsinbound.entity.PutawayTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface PutawayTaskRepository extends JpaRepository<PutawayTask, Long> {
    Optional<PutawayTask> findByExternalId(String externalId);
    List<PutawayTask> findByAsnId(Long asnId);
    List<PutawayTask> findByStatus(PutawayTask.Status status);
    boolean existsByAsnIdAndStatus(Long asnId, PutawayTask.Status status);
}
