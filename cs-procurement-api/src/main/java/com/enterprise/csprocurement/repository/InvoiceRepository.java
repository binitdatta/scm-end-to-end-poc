package com.enterprise.csprocurement.repository;

import com.enterprise.csprocurement.entity.Invoice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, Long> {
    Optional<Invoice> findByExternalId(String externalId);
    Optional<Invoice> findByInvoiceNumber(String invoiceNumber);
    boolean existsByInvoiceNumber(String invoiceNumber);
    List<Invoice> findByPurchaseOrderId(Long poId);
    List<Invoice> findByStatus(Invoice.Status status);
}
