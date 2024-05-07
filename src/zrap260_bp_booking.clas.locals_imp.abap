CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS calculatebookingid FOR DETERMINE ON MODIFY
      IMPORTING keys FOR booking~calculatebookingid.

    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR booking~calculatetotalprice.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD calculatebookingid.

    DATA max_bookingid TYPE /dmo/booking_id.
    DATA update TYPE TABLE FOR UPDATE zrap260_r_travel\\booking.

    " Read all travels for the requested bookings.
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    READ ENTITIES OF zrap260_r_travel IN LOCAL MODE
      ENTITY booking BY \_travel
        FIELDS ( traveluuid )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    " Process all affected Travels.
    " Read respective bookings, determine the max-id and update the bookings without ID.
    LOOP AT travels INTO DATA(travel).

      READ ENTITIES OF zrap260_r_travel IN LOCAL MODE
        ENTITY travel BY \_booking
          FIELDS ( bookingid )
        WITH VALUE #( ( %tky = travel-%tky ) )
        RESULT DATA(bookings).

      " Find max used BookingID in all bookings of this travel
      max_bookingid = '0000'.
      LOOP AT bookings INTO DATA(booking).
        IF booking-bookingid > max_bookingid.
          max_bookingid = booking-bookingid.
        ENDIF.
      ENDLOOP.

      " Provide a booking ID for all bookings that have none.
      LOOP AT bookings INTO booking WHERE bookingid IS INITIAL.
        max_bookingid += 10.
        APPEND VALUE #( %tky = booking-%tky
                        bookingid = max_bookingid ) TO update.
      ENDLOOP.

    ENDLOOP.

    " Update the Booking ID of all relevant bookings
    MODIFY ENTITIES OF zrap260_r_travel IN LOCAL MODE
      ENTITY booking
        UPDATE FIELDS ( bookingid ) WITH update
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.

  METHOD calculatetotalprice.

    " Read all travels for the requested bookings.
    " If multiple bookings of the same travel are requested, the travel is returned only once.
    READ ENTITIES OF zrap260_r_travel IN LOCAL MODE
      ENTITY booking BY \_travel
        FIELDS ( traveluuid )
        WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      FAILED DATA(read_failed).

    " Trigger calculation of the total price
    MODIFY ENTITIES OF zrap260_r_travel IN LOCAL MODE
      ENTITY travel
        EXECUTE recalctotalprice
        FROM CORRESPONDING #( travels )
      REPORTED DATA(execute_reported).

    reported = CORRESPONDING #( DEEP execute_reported ).

  ENDMETHOD.

ENDCLASS.

*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
