package com.enterprise.csvendor.repository;

import com.enterprise.csvendor.entity.Vendor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface VendorRepository extends JpaRepository<Vendor, Long> {
    Optional<Vendor> findByExternalId(String externalId);
    Optional<Vendor> findByVendorCode(String vendorCode);
    boolean existsByVendorCode(String vendorCode);
    List<Vendor> findByCountryAndStatus(Vendor.Country country, Vendor.Status status);
    List<Vendor> findByStatus(Vendor.Status status);
}
