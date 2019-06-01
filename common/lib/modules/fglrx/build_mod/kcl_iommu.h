/****************************************************************************
 *                                                                          *
 * Copyright 1999-2005 ATI Technologies Inc., Markham, Ontario, CANADA.     *
 * All Rights Reserved.                                                     *
 *                                                                          *
 * Your use and or redistribution of this software in source and \ or       *
 * binary form, with or without modification, is subject to: (i) your       *
 * ongoing acceptance of and compliance with the terms and conditions of    *
 * the ATI Technologies Inc. software End User License Agreement; and (ii)  *
 * your inclusion of this notice in any version of this software that you   *
 * use or redistribute.  A copy of the ATI Technologies Inc. software End   *
 * User License Agreement is included with this software and is also        *
 * available by contacting ATI Technologies Inc. at http://www.ati.com      *
 *                                                                          *
 ****************************************************************************/

/** \brief Declarations for KCL IOMMU supporting interfaces */

#ifndef KCL_IOMMU_H
#define KCL_IOMMU_H

#include "kcl_config.h"
#include "kcl_type.h"
#include "kcl_pci.h"

typedef union _iommu_req_perm_
{
    struct __packed__
    {
        uint32_t read    :  1;
        uint32_t write   :  1;
        uint32_t exec    :  1;
        uint32_t priv    :  1; 
        uint32_t res     :  28;  
    }flags;   
    uint32_t all;
} KCL_IOMMU_req_perm_t;

#define KCL_PRI_DEV_ERRATUM_ENABLE_RESET   0 
//This indicates that the PRI capability needs to be resetted while PRI being enabled. The Spec requires PRI to be disabled by default. 

#define KCL_PRI_DEV_ERRATUM_LIMIT_REQ_ONE  1
//This limits the number of outstanding PRI requests to one. 

#define MMIO_REGION_LENGTH       0x4000

#define MMIO_DEV_TABLE_OFFSET   0x0000
#define MMIO_CMD_BUF_OFFSET     0x0008
#define MMIO_EVT_BUF_OFFSET     0x0010
#define MMIO_CONTROL_OFFSET     0x0018
#define MMIO_EXCL_BASE_OFFSET   0x0020
#define MMIO_EXCL_LIMIT_OFFSET  0x0028
#define MMIO_EXT_FEATURES	0x0030
#define MMIO_PER_OPTCTL_OFFSET  0x016c
#define MMIO_CMD_HEAD_OFFSET	0x2000
#define MMIO_CMD_TAIL_OFFSET	0x2008
#define MMIO_EVT_HEAD_OFFSET	0x2010
#define MMIO_EVT_TAIL_OFFSET	0x2018
#define MMIO_STATUS_OFFSET	    0x2020

#define MMIO_EXCL_ENABLE_MASK   0x01ULL
#define MMIO_EXCL_ALLOW_MASK    0x02ULL
#define MMIO_PER_OPTEN_MASK     0x0d

typedef struct _iommu_info_
{
    int32_t max_pasids;            //maximum PASIDs supported by the device and the IOMMU in control of the device 
    int32_t gvas_size;             //maximum guest virtual address space supported by the iommu driver
    int32_t pas_size;              //maximum physical address generated by the iommu driver
    int32_t erratum_mask;          //bit mask of device specificed work around for iommu ,The bit is defined as KCL_PRI_DEV_ERRATUM_XXX  
    union 
    {
        struct  
        {
            uint32_t ats_sup:     1; // ATS features supported 
            uint32_t pri_sup:     1; // PRI features supported 
            uint32_t pasid_sup:   1; // PASID contexts supported
            uint32_t exec_sup:    1; // Device may request code execution privileges 
            uint32_t priv_sup:    1; // Device may request super-user privileges 
            uint32_t: 27;
        } f;
        uint32_t raw;
    }flags;
}  KCL_IOMMU_info_t;

//need to check iommu driver defines
typedef enum {
    KCL_IOMMU_PRI_SUCCESS,
    KCL_IOMMU_PRI_INVALID_RESPONSE,    
    KCL_IOMMU_PRI_RESPONSE_FAILURE,
    KCL_IOMMU_PRI_DROP,
}KCL_IOMMU_INVALID_PRI_RESPONSE;

#define IVRS_HEADER_LENGTH 48
#define ACPI_IVHD_TYPE                  0x10
#define ACPI_IVMD_TYPE_ALL              0x20
#define ACPI_IVMD_TYPE                  0x21
#define ACPI_IVMD_TYPE_RANGE            0x22

struct ivhd_header {
	kcl_u8 type;
	kcl_u8 flags;
	kcl_u16 length;
	kcl_u16 devid;
	kcl_u16 cap_ptr;
	kcl_u64 mmio_phys;
	kcl_u16 pci_seg;
	kcl_u16 info;
	kcl_u32 reserved;
} __attribute__((packed));   

int ATI_API_CALL KCL_IOMMU_InitDevice( KCL_PCI_DevHandle pcidev, KCL_IOMMU_info_t* pInfo);
void ATI_API_CALL KCL_IOMMU_FreeDevice( KCL_PCI_DevHandle pcidev);
int ATI_API_CALL KCL_IOMMU_BindPasid( KCL_PCI_DevHandle pcidev, int pid, int  pasid);
void ATI_API_CALL KCL_IOMMU_UnbindPasid( KCL_PCI_DevHandle pcidev, int  pasid);
int ATI_API_CALL KCL_IOMMU_RestorePasid( KCL_PCI_DevHandle pcidev, int pasid, void *task);
int ATI_API_CALL KCL_IOMMU_RestoreCBs( KCL_PCI_DevHandle pcidev);
int ATI_API_CALL KCL_IOMMU_CheckInfo( KCL_PCI_DevHandle pcidev);
void ATI_API_CALL KCL_IOMMU_SetExclusion(unsigned long long pa, unsigned long long length);
void ATI_API_CALL KCL_IOMMU_SetByPass (unsigned int flag);


#endif
