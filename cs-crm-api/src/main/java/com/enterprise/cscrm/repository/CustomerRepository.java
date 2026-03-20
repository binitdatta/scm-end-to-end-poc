package com.enterprise.cscrm.repository;

import com.enterprise.cscrm.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    Optional<Customer> findByExternalId(String externalId);
    Optional<Customer> findByEmail(String email);
    boolean existsByEmail(String email);
}
