package com.enterprise.csvendor.repository;

import com.enterprise.csvendor.entity.VendorQuote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface VendorQuoteRepository extends JpaRepository<VendorQuote, Long> {
    Optional<VendorQuote> findByExternalId(String externalId);
    List<VendorQuote> findByRfqId(Long rfqId);
    Optional<VendorQuote> findByRfqIdAndVendorId(Long rfqId, Long vendorId);
    boolean existsByRfqIdAndVendorId(Long rfqId, Long vendorId);
}
